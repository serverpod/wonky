import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/drive_l10n.dart';
import 'file_category_icon.dart';
import 'file_preview_controller.dart';
import 'preview_bars.dart';
import 'preview_commands.dart';
import 'preview_content.dart';
import 'preview_host.dart';
import 'viewers/csv_table_viewer.dart';
import 'viewers/image_viewer.dart';
import 'viewers/preview_states.dart';
import 'viewers/text_file_viewer.dart';

/// The file page `/file/:uuid` (Drive 02 §6, Drive 04 §6): a full-screen
/// in-app page with the top bar (back, name, *Open with*, *Download*,
/// *Share*, star, ⋮, details, close), the viewer for the file's type, the
/// viewer bar and ‹ › through the folder's files.
class FilePreviewScreen extends StatefulWidget {
  const FilePreviewScreen({
    super.key,
    required this.services,
    required this.itemUuid,
  });

  final ShellServices services;
  final String itemUuid;

  /// Below this width secondary buttons collapse into ⋮ and the details
  /// panel becomes an overlay (Drive 04 §11, `md`).
  static const narrowWidth = 768.0;

  static const rootKey = ValueKey<String>('drive.preview');

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  late final FilePreviewHost _host = FilePreviewHost.of(widget.services);
  late final FilePreviewController _c;
  final _focus = FocusNode(debugLabel: 'drive.preview');
  final _title = DocumentTitleFieldController();
  bool _redirected = false;

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    UuidValue uuid;
    try {
      uuid = UuidValue.withValidation(widget.itemUuid.toLowerCase());
    } on FormatException {
      // A malformed link: the server answers "not found".
      uuid = UuidValue.fromString('00000000-0000-0000-0000-000000000000');
    }
    _c = FilePreviewController(_host, uuid)..addListener(_onChanged);
    _host.active.value = _c;
    s.currentItem.addListener(_onCurrentItem);
    s.panels.addListener(_onChanged);
    s.startTitleRename = _title.startEditing;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (s.driveSelection.value.isNotEmpty) s.driveSelection.value = const [];
    });
    unawaited(_c.load());
  }

  @override
  void dispose() {
    s.currentItem.removeListener(_onCurrentItem);
    s.panels.removeListener(_onChanged);
    if (s.startTitleRename == _title.startEditing) s.startTitleRename = null;
    if (_host.active.value == _c) _host.active.value = null;
    _c
      ..removeListener(_onChanged)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_c.phase == PreviewPhase.notAFile && !_redirected) {
      _redirected = true;
      final item = _c.item!;
      WidgetsBinding.instance.addPostFrameCallback((_) => s.openItem(item));
    }
    setState(() {});
    s.registry.notifyStateChanged();
  }

  /// Renames, stars, trash and restore update `currentItem`.
  void _onCurrentItem() {
    final v = s.currentItem.value;
    if (v != null && v.uuid == _c.itemUuid && v != _c.item) {
      setState(() => _c.item = v);
      s.registry.notifyStateChanged();
    }
  }

  /// Single keys work only outside text fields (Drive 04 §10).
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus != null &&
        (focus.widget is EditableText ||
            focus.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return KeyEventResult.ignored;
    }
    return s.keymap.handle(event, previewKeyScope, context: context);
  }

  Future<void> _invoke(String id, [Map<String, Object?> args = const {}]) =>
      s.dispatcher.invoke(id, args: args, context: context);

  Widget _body(BuildContext context) {
    if (_c.phase != PreviewPhase.ready) return previewStateBody(context, _c);
    return switch (_c.type!.viewer) {
      PreviewViewer.image => ImageViewer(controller: _c),
      PreviewViewer.text => TextFileViewer(controller: _c),
      PreviewViewer.csv => CsvTableViewer(controller: _c),
      PreviewViewer.unsupported => UnsupportedFileView(controller: _c),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final details = s.panels.isOpen(ShellPanels.details) && _c.item != null;
    return Material(
      type: MaterialType.transparency,
      child: Focus(
        key: FilePreviewScreen.rootKey,
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: ColoredBox(
          color: cs.canvas,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final narrow = box.maxWidth < FilePreviewScreen.narrowWidth;
                final item = _c.item;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PreviewTopBar(
                      controller: _c,
                      narrow: narrow,
                      titleController: _title,
                      onInvoke: _invoke,
                    ),
                    const ShadSeparator.horizontal(margin: EdgeInsets.zero),
                    if (item != null && item.isTrashed)
                      _TrashedBanner(
                        onRestore: () => _invoke('shell.drive.restore', {
                          'uuids': [item.uuid.uuid],
                        }),
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _Stepper(
                                    controller: _c,
                                    onInvoke: _invoke,
                                    child: _body(context),
                                  ),
                                ),
                                if (details && !narrow) ...[
                                  const ShadSeparator.vertical(
                                    margin: EdgeInsets.zero,
                                  ),
                                  SizedBox(
                                    width: 320,
                                    child: _detailsPanel(cs),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (details && narrow) ...[
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () => _invoke('shell.file.details'),
                                child: const ColoredBox(
                                  color: Color(0x66000000),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              bottom: 0,
                              right: 0,
                              width: box.maxWidth < 360 ? box.maxWidth : 360,
                              child: _detailsPanel(cs),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_c.phase == PreviewPhase.ready &&
                        _c.type?.viewer != PreviewViewer.unsupported) ...[
                      const ShadSeparator.horizontal(margin: EdgeInsets.zero),
                      PreviewViewerBar(
                        controller: _c,
                        narrow: narrow,
                        onInvoke: _invoke,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsPanel(ShadColorScheme cs) => ColoredBox(
    key: const ValueKey<String>('drive.preview.details'),
    color: cs.background,
    child: DriveDetailsPanel(services: s, item: _c.item),
  );
}

/// The ‹ › buttons on the sides of the viewer (wide layouts).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.controller,
    required this.onInvoke,
    required this.child,
  });

  final FilePreviewController controller;
  final Future<void> Function(String id) onInvoke;
  final Widget child;

  static const prevKey = ValueKey<String>('drive.preview.previous');
  static const nextKey = ValueKey<String>('drive.preview.next');

  @override
  Widget build(BuildContext context) {
    final l = driveL10n(context);
    Widget arrow(Key key, IconData icon, String tip, String id) => Center(
      child: ShadTooltip(
        builder: (_) => Text(tip),
        child: ShadIconButton.outline(
          key: key,
          width: 36,
          height: 36,
          iconSize: 18,
          icon: Icon(icon),
          semanticLabel: tip,
          onPressed: () => onInvoke(id),
        ),
      ),
    );
    return Stack(
      children: [
        Positioned.fill(child: child),
        if (controller.hasPrevious)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: arrow(
              prevKey,
              LucideIcons.chevronLeft,
              l.previewPrevious,
              'drive.preview.previous',
            ),
          ),
        if (controller.hasNext)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: arrow(
              nextKey,
              LucideIcons.chevronRight,
              l.previewNext,
              'drive.preview.next',
            ),
          ),
      ],
    );
  }
}

class _TrashedBanner extends StatelessWidget {
  const _TrashedBanner({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l = driveL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return Container(
      key: const ValueKey<String>('drive.preview.trashed'),
      color: cs.muted,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(LucideIcons.trash2, size: 16, color: cs.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.previewTrashedBanner,
              style: theme.textTheme.small,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ShadButton.outline(
            key: const ValueKey<String>('drive.preview.restore'),
            size: ShadButtonSize.sm,
            onPressed: onRestore,
            child: Text(l.previewRestore),
          ),
        ],
      ),
    );
  }
}

/// The category glyph of the top bar.
Widget previewTitleIcon(FilePreviewController c) {
  final type = c.type;
  if (type == null) return const Icon(LucideIcons.file, size: 18);
  return FileCategoryIcon(type.category, size: 18, code: type.language != null);
}
