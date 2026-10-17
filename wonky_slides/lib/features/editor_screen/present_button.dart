import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../config/slides_features.dart';
import '../../l10n/slides_l10n.dart';
import '../collab/presence_widgets.dart'
    show PresentLiveDot, followPresenterMenuItems;

/// The **Present** split button of the title row (Slides 04 §3), before
/// *Share*: the main part presents from the current slide
/// (`slides.present.fromCurrent`, ⌘Enter); the chevron opens *Present from
/// beginning*, *Presenter view*, *Open on another device…*, *Rehearse*
/// and *Use phone as remote* (SL-41, hidden until built) and *Presenting
/// settings…*. Below 640 px only the
/// play icon shows, below 400 px without the chevron (Present and Share
/// stay visible at 360 px, 04 §16).
class PresentButton extends StatelessWidget {
  const PresentButton({super.key, required this.services});

  final ShellServices services;

  static const _menu = <MenuSpec>[
    MenuCommand('slides.present.fromStart', id: 'present.fromStart'),
    MenuCommand('slides.present.presenterView', id: 'present.presenterView'),
    MenuCommand(
      'slides.present.openOnAnotherDevice',
      id: 'present.openOnAnotherDevice',
    ),
    MenuCommand('slides.present.rehearse', id: 'present.rehearse'),
    MenuCommand('slides.present.remote', id: 'present.remote'),
    MenuSeparator(),
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([services.registry, services.activeDocument]),
    builder: (context, _) {
      final l = slidesL10n(context);
      final theme = ShadTheme.of(context);
      final width = MediaQuery.sizeOf(context).width;
      final compact = width < 640;
      final state = services.dispatcher.stateOf('slides.present.fromCurrent');
      final shortcut = services.keymap.shortcutTextOf(
        'slides.present.fromCurrent',
      );
      void present() => services.dispatcher.invoke(
        'slides.present.fromCurrent',
        source: InvocationSource.ui,
        context: context,
      );
      final reason = state.disabledReason;
      final main = ShadTooltip(
        builder: (_) => Text(
          !state.enabled && reason != null
              ? '${l.presentButton} — $reason'
              : shortcut == null
              ? l.cmdPresentFromCurrent
              : '${l.cmdPresentFromCurrent} ($shortcut)',
        ),
        child: compact
            ? ShadIconButton.secondary(
                key: const ValueKey<String>('slides.present'),
                width: 32,
                height: 32,
                iconSize: 16,
                semanticLabel: l.presentButton,
                enabled: state.enabled,
                icon: const Icon(LucideIcons.play),
                onPressed: present,
              )
            : ShadButton.secondary(
                key: const ValueKey<String>('slides.present'),
                height: 32,
                padding: const EdgeInsets.only(left: 10, right: 8),
                enabled: state.enabled,
                leading: const Icon(LucideIcons.play, size: 14),
                onPressed: present,
                child: Text(l.presentButton),
              ),
      );
      final chevron = WonkyDropdownMenu(
        anchor: const ShadAnchor(
          childAlignment: AlignmentDirectional.bottomEnd,
          overlayAlignment: AlignmentDirectional.topEnd,
          offset: Offset(0, 6),
        ),
        entries: () => [
          // *Follow Anna's presentation* while someone presents (SL-37).
          ...followPresenterMenuItems(context, services),
          ...MenuResolver(
            services,
          ).entries(context, SlidesFeatures.prune(_menu)),
          WonkyMenuItem(
            key: const ValueKey<String>('menu.present.settings'),
            label: l.menuPresentingSettings,
            icon: LucideIcons.settings2,
            onSelected: () => services.dispatcher.invoke(
              'shell.settings.openApp',
              args: const {'section': 'presenting'},
              source: InvocationSource.menu,
              context: context,
            ),
          ),
        ],
        builder: (context, c) => ShadTooltip(
          builder: (_) => Text(l.presentOptions),
          child: ShadIconButton.secondary(
            key: const ValueKey<String>('slides.present.menu'),
            width: 24,
            height: 32,
            iconSize: 14,
            semanticLabel: l.presentOptions,
            icon: Icon(
              LucideIcons.chevronDown,
              color: theme.colorScheme.secondaryForeground,
            ),
            onPressed: c.toggle,
          ),
        ),
      );
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 1,
          // Below 400 px the options stay in View › Present (04 §16).
          children: [
            // The live dot while a collaborator presents (SL-37, 09 §1.6).
            PresentLiveDot(services: services, child: main),
            if (width >= 400) chevron,
          ],
        ),
      );
    },
  );
}

/// *Present* in the title row of the mobile layout (04 §16.1): a play icon
/// that opens present mode at the current slide (`slides.present.fromSlide`,
/// never the presenter view), with the mobile presenter bar (10 §1.6).
class MobilePresentButton extends StatelessWidget {
  const MobilePresentButton({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([services.registry, services.activeDocument]),
    builder: (context, _) {
      final l = slidesL10n(context);
      final state = services.dispatcher.stateOf('slides.present.fromSlide');
      return ShadTooltip(
        builder: (_) => Text(l.cmdPresentFromCurrent),
        child: ShadIconButton.secondary(
          key: const ValueKey<String>('slides.mobile.present'),
          width: 36,
          height: 36,
          iconSize: 16,
          semanticLabel: l.presentButton,
          enabled: state.enabled,
          icon: const Icon(LucideIcons.play),
          onPressed: () => services.dispatcher.invoke(
            'slides.present.fromSlide',
            source: InvocationSource.ui,
            context: context,
          ),
        ),
      );
    },
  );
}
