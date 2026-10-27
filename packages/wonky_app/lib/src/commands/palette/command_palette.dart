import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../../branding/product_icon.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../shell/shell_services.dart';
import '../command.dart';
import 'palette_list.dart';
import '../../storage/quota_error_presenter.dart';

/// The command palette (suite 08 §1.3, `Mod+Shift+P`): fuzzy search over
/// titles, descriptions, aliases and menu paths; sections Recent / All
/// commands; extra providers "Go to document…" (drive search).
Future<void> showCommandPalette(BuildContext context, ShellServices s) {
  final menuPaths = s.menuPaths(context);
  final options = s
      .menuRoot(context)
      .parameterizedItems(
        titleOf: (c) => s.registry.byId(c.commandId)?.title(context) ?? '',
      );
  return showShadDialog<void>(
    context: context,
    builder: (context) => ShadDialog(
      key: const ValueKey<String>('palette'),
      padding: const EdgeInsets.all(12),
      // Esc closes; a close button would overlap the search field.
      closeIcon: const SizedBox.shrink(),
      constraints: const BoxConstraints(maxWidth: 620),
      child: SizedBox(
        width: 600,
        child: _CommandPaletteBody(
          services: s,
          menuPaths: menuPaths,
          options: options,
        ),
      ),
    ),
  );
}

class _CommandPaletteBody extends StatefulWidget {
  const _CommandPaletteBody({
    required this.services,
    required this.menuPaths,
    required this.options,
  });

  final ShellServices services;
  final Map<String, List<String>> menuPaths;

  /// Menu items with fixed arguments (radio options), searchable as their
  /// own rows: "dark" finds View › App theme › Dark.
  final List<({MenuCommand item, List<String> path})> options;

  @override
  State<_CommandPaletteBody> createState() => _CommandPaletteBodyState();
}

class _CommandPaletteBodyState extends State<_CommandPaletteBody> {
  List<DriveItemView> _docs = const [];
  String _docQuery = '';
  Timer? _debounce;

  ShellServices get s => widget.services;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _searchDocs(String q, PaletteListState state) {
    if (q == _docQuery) return;
    _docQuery = q;
    _debounce?.cancel();
    if (q.trim().length < 2) {
      _docs = const [];
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        final page = await s.drive.search(
          q,
          filters: DriveSearchFilters(),
          limit: 6,
        );
        if (!mounted || _docQuery != q) return;
        _docs = page.items;
        state.refresh();
      } catch (_) {}
    });
  }

  List<PaletteRow> _rows(
    BuildContext context,
    String q,
    PaletteListState state,
  ) {
    final l = WonkyAppLocalizations.of(context);
    final commands = [
      for (final c in s.registry.all)
        if (c.showInPalette && s.dispatcher.stateOf(c.id.value).visible) c,
    ];
    PaletteRow rowOf(
      Command<CommandArgs> c, {
      String? section,
      ({MenuCommand item, List<String> path})? option,
    }) {
      final id = c.id.value;
      final args = option?.item.args ?? const <String, Object?>{};
      final state = s.dispatcher.stateOf(id, args);
      final path = option?.path ?? widget.menuPaths[id];
      final label = option?.item.label;
      return PaletteRow(
        id: option == null ? id : '$id#${option.path.join('/')}',
        title: label == null ? c.title(context) : '${c.title(context)}: $label',
        subtitle: path == null ? c.description(context) : path.join(' › '),
        icon: c.icon,
        shortcut: option == null ? s.keymap.labelsOf(id) : null,
        enabled: state.enabled,
        disabledReason: state.disabledReason,
        section: section,
        onSelected: () {
          s.noteRecentCommand(id);
          unawaited(
            s.dispatcher
                .invoke(
                  id,
                  args: args,
                  source: InvocationSource.palette,
                  context: s.navigatorContext,
                )
                .catchError((Object e) {
                  if (!QuotaErrorPresenter.isQuotaExceeded(e)) {
                    s.toasts.error(l.commandFailed(id), description: '$e');
                  }
                  return const CommandResult.failed('error');
                }),
          );
        },
      );
    }

    if (q.trim().isEmpty) {
      final recent = [
        for (final id in s.recentCommands)
          if (commands.any((c) => c.id.value == id))
            commands.firstWhere((c) => c.id.value == id),
      ];
      final rest = [...commands]
        ..sort((a, b) => a.title(context).compareTo(b.title(context)));
      return [
        for (final c in recent) rowOf(c, section: l.paletteRecent),
        for (final c in rest) rowOf(c, section: l.paletteAllCommands),
      ];
    }
    _searchDocs(q, state);
    final byId = {for (final c in commands) c.id.value: c};
    final candidates =
        <(Command<CommandArgs>, ({MenuCommand item, List<String> path})?)>[
          for (final c in commands) (c, null),
          for (final o in widget.options)
            if (byId[o.item.commandId] case final c?) (c, o),
        ];
    final ranked = Fuzzy.rank(q, candidates, (e) {
      final (c, o) = e;
      if (o != null) return [o.item.label ?? '', o.path.join(' › ')];
      return [
        c.title(context),
        ...?widget.menuPaths[c.id.value]?.let((p) => [p.join(' › ')]),
        ...c.aliases(context),
        ?c.description(context),
        c.id.value,
      ];
    });
    return [
      for (final (c, o) in ranked)
        rowOf(c, option: o, section: l.paletteCommands),
      for (final d in _docs)
        PaletteRow(
          id: 'doc.${d.uuid.uuid}',
          title: d.name,
          subtitle: l.paletteGoToFile,
          leading: DriveKindIcon.item(d, size: 18),
          section: l.paletteFiles,
          onSelected: () => s.openItem(d),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    return PaletteList(
      placeholder: l.palettePlaceholder,
      emptyText: l.paletteEmpty,
      rows: (q, state) => _rows(context, q, state),
    );
  }
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
