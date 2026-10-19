import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_slides_core/clipboard.dart' show SlidesClipboardCodec;
import 'package:wonky_slides_core/copy.dart' show FileRehome;
import 'package:wonky_sync_models/ids.dart' show IdGenerator, SlidesIds;
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/slides_l10n.dart';

/// The themes of another presentation (`slidesThemes.list`, 05 §9).
class RemoteDeckThemes {
  const RemoteDeckThemes({
    required this.sourceItemUuid,
    required this.themes,
    this.defaultThemeId,
  });

  /// Parses the endpoint's JSON.
  factory RemoteDeckThemes.parse(String json) {
    final m = (jsonDecode(json) as Map).cast<String, Object?>();
    return RemoteDeckThemes(
      sourceItemUuid: m['sourceItemUuid']! as String,
      defaultThemeId: m['defaultThemeId'] as String?,
      themes: [
        for (final t in (m['themes'] as List?) ?? const [])
          if (t is Map) t.cast<String, Object?>(),
      ],
    );
  }

  final String sourceItemUuid;
  final String? defaultThemeId;

  /// Theme entries (`SlidesClipboardCodec.themeEntry` + `usedBy`).
  final List<Map<String, Object?>> themes;

  Map<String, Object?>? theme(String id) =>
      themes.where((t) => t['id'] == id).firstOrNull;

  /// The `DeckTheme.sourceKey` of a copy of [themeId].
  String sourceKeyOf(String themeId) =>
      SlidesIds.deckThemeSourceKey(sourceItemUuid, themeId);
}

/// *Import theme from a presentation…* (05 §9, P1 — the Sheets *Import
/// theme* pattern): picks a presentation, lists its themes and copies one
/// into the open deck; uploaded background and logo images are re-homed
/// into the open deck first (`file.copyToItem`, quota-checked). Needs the
/// server (the source deck is read online).
abstract final class ThemeImport {
  /// Test hook replacing `slidesThemes.list`.
  static Future<String> Function(UuidValue item)? debugFetch;

  /// Test hook replacing `file.copyToItem`.
  static Future<void> Function(FileRehome copy, UuidValue target)? debugCopy;

  /// The themes of presentation [item]; throws [StateError] offline.
  static Future<RemoteDeckThemes> fetch(ShellServices s, UuidValue item) async {
    final hook = debugFetch;
    if (hook != null) return RemoteDeckThemes.parse(await hook(item));
    final client = s.client;
    if (client == null) throw StateError('offline');
    return RemoteDeckThemes.parse(await client.slidesThemes.list(item));
  }

  /// Re-homes the files [entry] references into [target]: returns the
  /// entry with the copies' uuids (deterministic per copied theme, so a
  /// repeated import reuses the same copies) after copying them.
  static Future<Map<String, Object?>> rehome(
    ShellServices s,
    Map<String, Object?> entry, {
    required String themeId,
    required UuidValue target,
  }) async {
    final payload = {
      'themes': [entry],
    };
    final (out, copies) = SlidesClipboardCodec.rehomeFiles(
      payload,
      ids: _PartIds(themeId),
    );
    if (copies.isEmpty) return entry;
    for (final c in copies) {
      final hook = debugCopy;
      if (hook != null) {
        await hook(c, target);
        continue;
      }
      final client = s.client;
      if (client == null) throw StateError('offline');
      await client.file.copyToItem(
        UuidValue.withValidation(c.sourceFileUuid),
        UuidValue.withValidation(c.newFileUuid),
        target,
      );
    }
    return ((out['themes']! as List).single as Map).cast<String, Object?>();
  }

  /// Picks a presentation other than [exclude] (null when cancelled).
  static Future<DriveItemView?> pickPresentation(
    BuildContext context,
    ShellServices services, {
    UuidValue? exclude,
  }) => showShadDialog<DriveItemView>(
    context: context,
    builder: (_) =>
        PresentationPickerDialog(services: services, exclude: exclude),
  );

  /// Asks which theme of [source] to import (a select, MCP-operable); the
  /// only theme is chosen without asking.
  static Future<String?> chooseTheme(
    BuildContext context,
    RemoteDeckThemes source,
  ) async {
    if (source.themes.isEmpty) return null;
    if (source.themes.length == 1) return source.themes.single['id'] as String?;
    final l = slidesL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final r = await showWonkyFormDialog(
      context,
      WonkyDialogSpec(
        title: l.themeImportChooseTitle,
        dialogKey: 'dialog.slides.importTheme',
        fields: [
          SelectFieldSpec(
            id: 'theme',
            label: l.sectionTheme,
            options: {
              for (final t in source.themes)
                '${t['id']}': l.themeImportOption(
                  '${t['name'] ?? ''}',
                  (t['usedBy'] as num?)?.toInt() ?? 0,
                ),
            },
            initial: source.defaultThemeId ?? '${source.themes.first['id']}',
          ),
        ],
        buttons: [
          DialogButtonSpec(id: 'cancel', label: la.actionCancel),
          DialogButtonSpec(
            id: 'import',
            label: l.themeImportButton,
            primary: true,
          ),
        ],
      ),
    );
    if (r?.buttonId != 'import') return null;
    final id = r!.text('theme');
    return id.isEmpty ? null : id;
  }
}

/// Ids of re-homed files: `themePartId(theme, "file:<n>")` in scan order.
class _PartIds implements IdGenerator {
  _PartIds(this.themeId);

  final String themeId;
  int _n = 0;

  @override
  String newId() => SlidesIds.themePartId(themeId, 'file:${_n++}');
}

/// Picks another presentation the user can open (recent ones, or a
/// search): *Import theme from a presentation…*. Custom dialog,
/// MCP-operable (`search` text, `presentation` select, *Cancel*).
class PresentationPickerDialog extends StatefulWidget {
  const PresentationPickerDialog({
    super.key,
    required this.services,
    this.exclude,
  });

  final ShellServices services;
  final UuidValue? exclude;

  @override
  State<PresentationPickerDialog> createState() =>
      _PresentationPickerDialogState();
}

class _PresentationPickerDialogState extends State<PresentationPickerDialog>
    implements McpDescribableDialog {
  final _search = TextEditingController();
  Timer? _debounce;
  List<DriveItemView> _items = const [];
  bool _loading = true;
  bool _failed = false;
  ShellServices? _registeredIn;

  @override
  void initState() {
    super.initState();
    unawaited(_find());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context) ?? widget.services;
    _registeredIn = s;
    if (!s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _close([DriveItemView? item]) => Navigator.of(context).pop(item);

  Future<void> _find() async {
    final q = _search.text.trim();
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final drive = widget.services.drive;
      final page = q.isEmpty
          ? await drive.list(
              filter: DriveListFilter(
                view: DriveView.recent,
                kinds: [DriveItemKind.presentation],
              ),
              sort: DriveSort(
                field: DriveSortField.lastOpenedByMe,
                descending: true,
              ),
              limit: 30,
            )
          : await drive.search(
              q,
              filters: DriveSearchFilters(kinds: [DriveItemKind.presentation]),
              limit: 30,
            );
      if (!mounted) return;
      setState(() {
        _items = [
          for (final i in page.items)
            if (i.kind == DriveItemKind.presentation &&
                i.uuid != widget.exclude)
              i,
        ];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Map<String, Object?> describe() {
    final l = slidesL10n(context);
    return {
      'title': l.themeImportPickTitle,
      'fields': [
        {
          'id': 'search',
          'label': l.themeImportSearch,
          'type': 'text',
          'value': _search.text,
        },
        {
          'id': 'presentation',
          'label': l.themeImportPresentation,
          'type': 'select',
          'options': [for (final i in _items) i.uuid.uuid],
          'optionLabels': {for (final i in _items) i.uuid.uuid: i.name},
        },
      ],
      'buttons': [
        {
          'id': 'cancel',
          'label': WonkyAppLocalizations.of(context).actionCancel,
        },
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'search' when value is String:
        _search.text = value;
        unawaited(_find());
        return true;
      case 'presentation' when value is String:
        final i = _items
            .where((x) => x.uuid.uuid == value || x.name == value)
            .firstOrNull;
        if (i == null) return false;
        _close(i);
        return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    if (buttonId != 'cancel') return false;
    _close();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = slidesL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _close(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('slides.dialog.pickPresentation'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.themeImportPickTitle),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('slides.pickPresentation.cancel'),
            onPressed: () => _close(),
            child: Text(la.actionCancel),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SizedBox(
            width: double.infinity,
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShadInput(
                  key: const ValueKey<String>('slides.pickPresentation.search'),
                  controller: _search,
                  autofocus: true,
                  placeholder: Text(l.themeImportSearch),
                  leading: const Icon(LucideIcons.search, size: 16),
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 250), _find);
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loading
                      ? const Center(child: ShadSpinner())
                      : _failed || _items.isEmpty
                      ? Center(
                          child: Text(
                            _failed
                                ? l.themeImportOffline
                                : l.themeImportNoPresentations,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.muted,
                          ),
                        )
                      : ListView(
                          children: [
                            for (final i in _items)
                              ShadButton.ghost(
                                key: ValueKey<String>(
                                  'slides.pickPresentation.item.${i.uuid}',
                                ),
                                width: double.infinity,
                                mainAxisAlignment: MainAxisAlignment.start,
                                leading: const Icon(
                                  LucideIcons.presentation,
                                  size: 16,
                                ),
                                onPressed: () => _close(i),
                                child: Expanded(
                                  child: Text(
                                    i.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
