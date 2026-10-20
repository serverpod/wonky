import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../assistant/ai_providers_section.dart';
import '../assistant/shell_assistant.dart' show ShellAssistant;
import '../bootstrap/app_urls.dart';
import '../branding/product_icon.dart';
import '../config/wonky_app_config.dart';
import '../l10n/wonky_app_localizations.dart';
import '../shell/account_menu.dart' show productOf;
import '../shell/page_frame.dart';
import '../shell/shell_services.dart';
import 'sections/account_section.dart';
import 'sections/appearance_section.dart';
import 'sections/keyboard_section.dart';
import 'sections/other_sections.dart';
import '../publications/publications_section.dart';
import 'sections/security_section.dart';
import 'sections/storage_section.dart';
import 'settings_catalog.dart';

export 'settings_catalog.dart' show SettingsArea;

/// A section of the settings nav.
class _Section {
  const _Section(this.area, this.id, this.title, this.icon, this.builder);
  final SettingsArea area;
  final String id;
  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  String get path => settingsPath(area, id);
  String get navKey =>
      area == SettingsArea.app ? 'settings.nav.app.$id' : 'settings.nav.$id';
  String get contentKey => area == SettingsArea.app
      ? 'settings.section.app.$id'
      : 'settings.section.$id';
}

/// The short name of [app] ("Sheets" of "Wonky Sheets").
String _shortName(WonkyAppKind app) => app.shortName;

/// The settings screen (suite 04 §4.2): a left nav with two groups — the
/// current app's settings (`/settings/app/:section`,
/// `WonkyAppConfig.appSettingsSections`) first, then the Wonky Work settings
/// (`/settings/:section`) — and the open section. Below 760 px the nav is a
/// select above the content. Every change is a command or a preference
/// write; settings are not undoable.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.services,
    required this.section,
    this.area = SettingsArea.work,
  });

  final ShellServices services;

  /// The open section's id in [area]; unknown ids show the area's first
  /// section.
  final String section;
  final SettingsArea area;

  List<_Section> _workSections(WonkyAppLocalizations l) {
    final s = services;
    _Section w(String id, String title, IconData icon, WidgetBuilder b) =>
        _Section(SettingsArea.work, id, title, icon, b);
    return [
      w(
        'account',
        l.settingsAccountProfile,
        LucideIcons.user,
        (_) => AccountSection(services: s),
      ),
      w(
        'security',
        l.settingsSecurity,
        LucideIcons.shieldCheck,
        (_) => SecuritySection(services: s),
      ),
      w(
        'appearance',
        l.settingsAppearance,
        LucideIcons.palette,
        (_) => AppearanceSection(services: s),
      ),
      w(
        'language',
        l.settingsLanguage,
        LucideIcons.languages,
        (_) => LanguageSection(services: s),
      ),
      w(
        'keyboard',
        l.settingsKeyboard,
        LucideIcons.keyboard,
        (_) => KeyboardSection(services: s),
      ),
      w(
        'notifications',
        l.settingsNotifications,
        LucideIcons.bell,
        (_) => NotificationsSection(services: s),
      ),
      w(
        'storage',
        l.settingsStorage,
        LucideIcons.chartPie,
        (_) => StorageSection(services: s),
      ),
      w(
        'offline',
        l.settingsOffline,
        LucideIcons.hardDrive,
        (_) => OfflineSection(services: s),
      ),
      w(
        'ai',
        l.settingsAi,
        LucideIcons.sparkles,
        (_) => AiSection(services: s),
      ),
      w(
        ShellAssistant.aiProvidersSection,
        l.settingsAiProviders,
        LucideIcons.keyRound,
        (_) => AiProvidersSection(services: s),
      ),
      w(
        'developer',
        l.settingsDeveloper,
        LucideIcons.squareTerminal,
        (_) => DeveloperSection(services: s),
      ),
      // (M14) Blogs that take stories from Wonky Write (specs/18 §8.1).
      if (s.repositories.hasPublications)
        w(
          'publications',
          l.settingsPublications,
          LucideIcons.newspaper,
          (_) => PublicationsSection(services: s),
        ),
      w(
        'about',
        l.settingsAbout,
        LucideIcons.info,
        (_) => AboutSection(services: s),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final s = services;
    final app = [
      for (final SettingsSectionSpec x in s.config.appSettingsSections(s))
        _Section(SettingsArea.app, x.id, x.title(context), x.icon, x.builder),
    ];
    final work = _workSections(l);
    final inArea = area == SettingsArea.app && app.isNotEmpty ? app : work;
    final current = inArea.firstWhere(
      (x) => x.id == section,
      orElse: () => inArea.first,
    );
    final appTitle = l.cmdAppSettings(s.config.shortAppName);
    final title = current.area == SettingsArea.app
        ? appTitle
        : l.cmdWorkSettings;
    final narrow = MediaQuery.sizeOf(context).width < shellPageNarrowWidth;
    final content = ShellPageBody(
      key: ValueKey<String>(current.contentKey),
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text(current.title, style: theme.textTheme.h3),
        ),
        const SizedBox(height: 20),
        current.builder(context),
      ],
    );
    return ShellPageFrame(
      services: s,
      title: title,
      onBack: () => s.router.go(settingsBackTarget(s)),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.colorScheme.border),
                    ),
                  ),
                  child: _NavSelect(
                    services: s,
                    app: app,
                    work: work,
                    current: current,
                    appTitle: appTitle,
                  ),
                ),
                Expanded(child: content),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: theme.colorScheme.border),
                    ),
                  ),
                  child: SizedBox(
                    width: 248,
                    child: _NavList(
                      services: s,
                      app: app,
                      work: work,
                      current: current,
                      appTitle: appTitle,
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            ),
    );
  }
}

/// A group header of the nav: the product icon and the group's name
/// (`Semantics(header: true)`).
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.product, required this.label, super.key});

  final WonkyProduct product;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Semantics(
      header: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Row(
          children: [
            WonkyProductIcon(product, size: 18, semanticLabel: ''),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The wide nav: app group (sections + *Settings of other apps*), then the
/// Wonky Work group.
class _NavList extends StatefulWidget {
  const _NavList({
    required this.services,
    required this.app,
    required this.work,
    required this.current,
    required this.appTitle,
  });

  final ShellServices services;
  final List<_Section> app;
  final List<_Section> work;
  final _Section current;
  final String appTitle;

  @override
  State<_NavList> createState() => _NavListState();
}

class _NavListState extends State<_NavList> {
  bool _others = false;

  Widget _entry(_Section x) {
    final theme = ShadTheme.of(context);
    final active = identical(x, widget.current);
    return Semantics(
      selected: active,
      child: ShadButton.ghost(
        key: ValueKey<String>(x.navKey),
        mainAxisAlignment: MainAxisAlignment.start,
        backgroundColor: active ? theme.colorScheme.sidebarAccent : null,
        leading: Icon(x.icon, size: 16),
        onPressed: () => widget.services.router.go(x.path),
        child: Flexible(child: Text(x.title, overflow: TextOverflow.ellipsis)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final s = widget.services;
    final others = [
      for (final a in WonkyAppKind.values)
        if (a != s.config.app) a,
    ];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (widget.app.isNotEmpty) ...[
          _GroupHeader(
            key: const ValueKey<String>('settings.group.app'),
            product: productOf(s.config.app),
            label: widget.appTitle,
          ),
          for (final x in widget.app) _entry(x),
          ShadButton.ghost(
            key: const ValueKey<String>('settings.nav.otherApps'),
            mainAxisAlignment: MainAxisAlignment.start,
            leading: Icon(
              _others ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              size: 16,
            ),
            onPressed: () => setState(() => _others = !_others),
            child: Flexible(
              child: Text(l.settingsOtherApps, overflow: TextOverflow.ellipsis),
            ),
          ),
          if (_others)
            for (final a in others)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ShadButton.ghost(
                  key: ValueKey<String>('settings.nav.other.${a.name}'),
                  mainAxisAlignment: MainAxisAlignment.start,
                  leading: WonkyProductIcon(
                    productOf(a),
                    size: 16,
                    semanticLabel: '',
                  ),
                  onPressed: () => s.crossApp.open(a, '/settings/app'),
                  child: Flexible(
                    child: Text(
                      l.cmdAppSettings(_shortName(a)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 8),
        ],
        _GroupHeader(
          key: const ValueKey<String>('settings.group.work'),
          product: WonkyProduct.work,
          label: l.cmdWorkSettings,
        ),
        for (final x in widget.work) _entry(x),
      ],
    );
  }
}

/// The narrow nav: one select listing both groups (and the other apps'
/// settings) above the content.
class _NavSelect extends StatelessWidget {
  const _NavSelect({
    required this.services,
    required this.app,
    required this.work,
    required this.current,
    required this.appTitle,
  });

  final ShellServices services;
  final List<_Section> app;
  final List<_Section> work;
  final _Section current;
  final String appTitle;

  static String _value(_Section x) => '${x.area.name}:${x.id}';

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final s = services;
    final all = [...app, ...work];
    Widget header(WonkyProduct p, String label) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          WonkyProductIcon(p, size: 16, semanticLabel: ''),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.muted.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    ShadOption<String> option(_Section x) => ShadOption<String>(
      value: _value(x),
      child: Row(
        children: [
          Icon(x.icon, size: 16),
          const SizedBox(width: 8),
          Flexible(child: Text(x.title, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    return Semantics(
      label: l.settingsSectionPicker,
      child: ShadSelect<String>(
        key: ValueKey<String>('settings.nav.select.${_value(current)}'),
        initialValue: _value(current),
        maxHeight: 420,
        options: [
          if (app.isNotEmpty) ...[
            header(productOf(s.config.app), appTitle),
            for (final x in app) option(x),
            for (final a in WonkyAppKind.values)
              if (a != s.config.app)
                ShadOption<String>(
                  value: 'other:${a.name}',
                  child: Row(
                    children: [
                      WonkyProductIcon(
                        productOf(a),
                        size: 16,
                        semanticLabel: '',
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l.cmdAppSettings(_shortName(a)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
          header(WonkyProduct.work, l.cmdWorkSettings),
          for (final x in work) option(x),
        ],
        selectedOptionBuilder: (context, v) {
          final x = all.where((x) => _value(x) == v).firstOrNull ?? current;
          final label = x.area == SettingsArea.app
              ? appTitle
              : l.cmdWorkSettings;
          return Text('$label › ${x.title}', overflow: TextOverflow.ellipsis);
        },
        onChanged: (v) {
          if (v == null) return;
          if (v.startsWith('other:')) {
            s.crossApp.open(
              WonkyAppKind.values.byName(v.substring(6)),
              '/settings/app',
            );
            return;
          }
          final x = all.where((x) => _value(x) == v).firstOrNull;
          if (x != null) s.router.go(x.path);
        },
      ),
    );
  }
}

/// A titled group of settings.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.title,
    this.description,
    required this.children,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ShadCard(
        title: Text(title),
        description: description == null ? null : Text(description!),
        backgroundColor: theme.colorScheme.card,
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A label + control row.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.description,
    required this.control,
  });

  final String label;
  final String? description;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final toggle = control is ShadSwitch || control is ShadCheckbox;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.small),
        if (description != null)
          Text(
            description!,
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
      ],
    );
    final row = LayoutBuilder(
      builder: (context, c) =>
          // Narrow (360 px pages): wide controls go below their label.
          !toggle && c.maxWidth < 400
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                text,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: control,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 16),
                control,
              ],
            ),
    );
    // A switch or checkbox has no text of its own: the row's label names it
    // for screen readers (labeledTapTargetGuideline).
    return toggle ? MergeSemantics(child: row) : row;
  }
}
