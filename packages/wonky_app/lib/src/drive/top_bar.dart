import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../bootstrap/app_urls.dart';
import '../branding/product_icon.dart';
import '../l10n/wonky_app_localizations.dart';
import '../notifications/notifications_button.dart';
import '../shell/account_menu.dart';
import '../shell/shell_services.dart';
import 'home_sidebar.dart' show HomeNewButton;

/// The home top bar (suite 05 §3.1 `WonkyTopBar`): hamburger, logo + name,
/// *+ New* while the left menu is collapsed ([showNewButton]), drive search
/// with suggestions, theme toggle, notifications and the account menu.
class WonkyTopBar extends StatelessWidget {
  const WonkyTopBar({
    super.key,
    required this.services,
    required this.onToggleSidebar,
    required this.searchFocus,
    this.initialQuery,
    this.contentStart,
    this.showNewButton = false,
  });

  final ShellServices services;
  final VoidCallback onToggleSidebar;
  final FocusNode searchFocus;
  final String? initialQuery;

  /// Where the page content starts (from the left edge) while the sidebar is
  /// open: the search field starts there too, aligned with the content
  /// below. Null: right after the logo.
  final double? contentStart;

  /// Shows *+ New* before the search field (Drive with the left menu
  /// collapsed or in a drawer, Drive 04 §2).
  final bool showNewButton;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 640;
    const padding = 12.0;
    final leading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShadTooltip(
          builder: (_) => Text(l.toggleSidebar),
          child: ShadIconButton.ghost(
            key: const ValueKey<String>('shell.topBar.menu'),
            semanticLabel: l.toggleSidebar,
            icon: const Icon(LucideIcons.menu, size: 18),
            onPressed: onToggleSidebar,
          ),
        ),
        const SizedBox(width: 4),
        // A labelled button: below 640 px the logo shows without the name.
        Semantics(
          button: true,
          label: services.config.shortAppName,
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey<String>('shell.topBar.home'),
            onTap: () => services.router.go('/'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  services.config.logo(size: 32),
                  if (!narrow) ...[
                    const SizedBox(width: 10),
                    Text(
                      services.config.shortAppName,
                      style: theme.textTheme.large.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
    final start = contentStart;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        children: [
          if (start != null && !narrow)
            SizedBox(
              width: start - padding,
              child: Align(alignment: Alignment.centerLeft, child: leading),
            )
          else ...[
            leading,
            SizedBox(width: showNewButton ? 16 : 24),
          ],
          if (showNewButton) ...[
            HomeNewButton(services: services, compact: true),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: DriveSearchField(
                  services: services,
                  focusNode: searchFocus,
                  initialQuery: initialQuery,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ThemeToggleButton(services: services),
          NotificationsButton(services: services),
          const SizedBox(width: 4),
          AccountMenuButton(services: services),
        ],
      ),
    );
  }
}

/// Drive search with a suggestions dropdown (recent searches, matching
/// items, "Search for '…'").
class DriveSearchField extends StatefulWidget {
  const DriveSearchField({
    super.key,
    required this.services,
    required this.focusNode,
    this.initialQuery,
  });

  final ShellServices services;
  final FocusNode focusNode;
  final String? initialQuery;

  @override
  State<DriveSearchField> createState() => _DriveSearchFieldState();
}

class _DriveSearchFieldState extends State<DriveSearchField> {
  late final _text = TextEditingController(text: widget.initialQuery ?? '');
  final _popover = ShadPopoverController();
  List<DriveItemView> _matches = const [];
  Timer? _debounce;

  ShellServices get s => widget.services;

  List<String> get _recent => [
    for (final q
        in (s.prefs.device<List<Object?>>('search.recent') ?? const []))
      '$q',
  ];

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (widget.focusNode.hasFocus) {
        _popover.show();
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _popover.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _popover.show();
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _matches = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        // App homes search their kind only (suite 03 §3.3).
        final p = await s.drive.search(
          q,
          filters: DriveSearchFilters(kinds: s.config.homeScope?.searchKinds),
          limit: 6,
        );
        if (mounted && _text.text == q) setState(() => _matches = p.items);
      } catch (_) {}
    });
  }

  void _submit(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    final recent = [t, ..._recent.where((r) => r != t)].take(8).toList();
    s.prefs.setDevice('search.recent', recent);
    _popover.hide();
    widget.focusNode.unfocus();
    s.router.go('/search?q=${Uri.encodeQueryComponent(t)}');
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return ShadPopover(
      controller: _popover,
      padding: const EdgeInsets.all(4),
      anchor: WonkyMenuPlacement.onScreen(
        const ShadAnchor(
          childAlignment: AlignmentDirectional.bottomStart,
          overlayAlignment: AlignmentDirectional.topStart,
          offset: Offset(0, 4),
        ),
      ),
      popover: (context) {
        final q = _text.text.trim();
        final recent = q.isEmpty ? _recent : const <String>[];
        if (q.isEmpty && recent.isEmpty) {
          return SizedBox(
            width: 520,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l.searchHint, style: theme.textTheme.muted),
            ),
          );
        }
        return SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in recent)
                ShadButton.ghost(
                  mainAxisAlignment: MainAxisAlignment.start,
                  leading: const Icon(LucideIcons.history, size: 16),
                  onPressed: () {
                    _text.text = r;
                    _submit(r);
                  },
                  child: Text(r),
                ),
              for (final m in _matches)
                ShadButton.ghost(
                  mainAxisAlignment: MainAxisAlignment.start,
                  leading: DriveKindIcon.item(m, size: 18),
                  onPressed: () {
                    _popover.hide();
                    s.openItem(m);
                  },
                  child: Expanded(
                    child: Text(m.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              if (q.isNotEmpty)
                ShadButton.ghost(
                  key: const ValueKey<String>('drive.search.submit'),
                  mainAxisAlignment: MainAxisAlignment.start,
                  leading: const Icon(LucideIcons.search, size: 16),
                  onPressed: () => _submit(q),
                  child: Text(l.searchFor(q)),
                ),
              if (q.isNotEmpty && s.config.homeScope?.kind != null)
                ShadButton.ghost(
                  key: const ValueKey<String>('drive.search.allDrive'),
                  mainAxisAlignment: MainAxisAlignment.start,
                  leading: const WonkyProductIcon(
                    WonkyProduct.drive,
                    size: 16,
                    semanticLabel: '',
                  ),
                  onPressed: () {
                    _popover.hide();
                    s.crossApp.open(
                      WonkyAppKind.drive,
                      '/search?q=${Uri.encodeQueryComponent(q)}',
                    );
                  },
                  child: Expanded(
                    child: Text(
                      l.searchAllDrive(q),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            _popover.hide();
            widget.focusNode.unfocus();
          },
        },
        child: ShadInput(
          key: const ValueKey<String>('drive.search'),
          controller: _text,
          focusNode: widget.focusNode,
          placeholder: Text(l.searchPlaceholder),
          leading: const Icon(LucideIcons.search, size: 16),
          trailing: _text.text.isEmpty
              ? null
              : ShadIconButton.ghost(
                  width: 24,
                  height: 24,
                  iconSize: 14,
                  semanticLabel: l.actionClear,
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    _text.clear();
                    _onChanged('');
                  },
                ),
          onChanged: _onChanged,
          onSubmitted: _submit,
          onPressedOutside: (_) => _popover.hide(),
        ),
      ),
    );
  }
}
