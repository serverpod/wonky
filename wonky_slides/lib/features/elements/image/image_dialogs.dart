import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_slides_core/scene.dart' show ShapeCategory, ShapeLibrary;
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../../l10n/slides_l10n.dart';

/// The sources of *Insert image* (03 §6.5.1, 04 §4.4).
const imageSources = ['upload', 'drive', 'url', 'clipboard'];

/// The source chooser of *Insert image* / *Replace image* without a
/// source (palette, agents' dialogs): a select of the four sources.
/// MCP-operable (`WonkyDialogSpec`). Returns the source or null.
Future<String?> showImageSourceDialog(
  BuildContext context, {
  bool replace = false,
}) async {
  final l = slidesL10n(context);
  final la = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: replace ? l.imageReplaceDialogTitle : l.imageInsertDialogTitle,
      dialogKey: 'dialog.slides.imageSource',
      fields: [
        SelectFieldSpec(
          id: 'source',
          label: l.imageSourceLabel,
          initial: 'upload',
          options: {
            'upload': l.imageUpload,
            'drive': l.imageFromDrive,
            'url': l.imageByUrl,
            'clipboard': l.imageFromClipboard,
          },
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: la.actionCancel),
        DialogButtonSpec(id: 'ok', label: l.dialogContinue, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  return r!.text('source');
}

/// Whether [url] is an https URL the image proxy accepts.
bool isImageUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

/// *Insert image ▸ By URL* (04 §13.2): an https address. MCP-operable.
/// Returns the URL or null.
Future<String?> showImageUrlDialog(BuildContext context) async {
  final l = slidesL10n(context);
  final la = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.imageUrlDialogTitle,
      description: l.imageUrlDialogBody,
      dialogKey: 'dialog.slides.imageUrl',
      fields: [
        TextFieldSpec(
          id: 'url',
          label: l.imageUrlLabel,
          placeholder: 'https://',
          validator: (v) => isImageUrl(v) ? null : l.imageUrlInvalid,
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: la.actionCancel),
        DialogButtonSpec(
          id: 'insert',
          label: l.dialogInsert,
          primary: true,
          validates: true,
        ),
      ],
    ),
  );
  if (r?.buttonId != 'insert') return null;
  return r!.text('url').trim();
}

/// *Mask with shape* (03 §6.5.3): the basic shapes and *No mask*.
/// MCP-operable. Returns the geometry key, `none`, or null when cancelled.
Future<String?> showImageMaskDialog(
  BuildContext context, {
  String? current,
}) async {
  final l = slidesL10n(context);
  final la = WonkyAppLocalizations.of(context);
  final shapes = [
    for (final g in ShapeLibrary.all)
      if (g.category == ShapeCategory.basic) g.key,
  ];
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.imageMaskDialogTitle,
      dialogKey: 'dialog.slides.imageMask',
      fields: [
        SelectFieldSpec(
          id: 'geometry',
          label: l.imageMaskShape,
          initial: current != null && shapes.contains(current)
              ? current
              : 'none',
          options: {
            'none': l.imageMaskNone,
            for (final k in shapes) k: l.shapeName(k),
          },
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: la.actionCancel),
        DialogButtonSpec(id: 'apply', label: l.dialogApply, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'apply') return null;
  return r!.text('geometry');
}

/// *Insert image ▸ From Wonky Drive* (03 §6.5.1): the user's image files
/// (recent ones, or a search), filtered to images. MCP-operable (fields
/// `search` and `image`; button `cancel`). Returns the drive item.
Future<DriveItemView?> showDriveImagePicker(
  BuildContext context,
  ShellServices services,
) => showShadDialog<DriveItemView>(
  context: context,
  builder: (_) => DriveImagePickerDialog(services: services),
);

class DriveImagePickerDialog extends StatefulWidget {
  const DriveImagePickerDialog({super.key, required this.services});

  final ShellServices services;

  @override
  State<DriveImagePickerDialog> createState() => _DriveImagePickerState();
}

class _DriveImagePickerState extends State<DriveImagePickerDialog>
    implements McpDescribableDialog {
  final _search = TextEditingController();
  Timer? _debounce;
  ShellServices? _registeredIn;
  List<DriveItemView> _items = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_find());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    _registeredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

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
                kinds: [DriveItemKind.file],
                fileCategories: [FileCategory.image],
              ),
              sort: DriveSort(
                field: DriveSortField.lastOpenedByMe,
                descending: true,
              ),
              limit: 50,
            )
          : await drive.search(
              q,
              filters: DriveSearchFilters(
                kinds: [DriveItemKind.file],
                fileCategories: [FileCategory.image],
              ),
              limit: 50,
            );
      if (!mounted) return;
      setState(() {
        _items = [
          for (final i in page.items)
            if (i.kind == DriveItemKind.file &&
                i.fileCategory == FileCategory.image &&
                i.contentRef != null &&
                i.trashedAt == null)
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

  void _close(DriveItemView? item) => Navigator.of(context).pop(item);

  @override
  Map<String, Object?> describe() => {
    'title': slidesL10n(context).imageDriveDialogTitle,
    'fields': [
      {
        'id': 'search',
        'label': slidesL10n(context).imageDriveSearch,
        'type': 'text',
        'value': _search.text,
      },
      {
        'id': 'image',
        'label': slidesL10n(context).imageDriveImage,
        'type': 'select',
        'options': [for (final i in _items) i.name],
      },
    ],
    'buttons': [
      {'id': 'cancel', 'label': 'Cancel'},
    ],
  };

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'search' when value is String:
        _search.text = value;
        unawaited(_find());
        return true;
      case 'image' when value is String:
        final i = _items.where((x) => x.name == value).firstOrNull;
        if (i == null) return false;
        _close(i);
        return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    if (buttonId != 'cancel') return false;
    _close(null);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = slidesL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    Widget body;
    if (_loading) {
      body = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: ShadSpinner()),
      );
    } else if (_failed || _items.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _failed ? l.imageDriveFailed : l.imageDriveEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.muted,
        ),
      );
    } else {
      body = ListView.builder(
        shrinkWrap: true,
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return ShadButton.ghost(
            key: ValueKey<String>('slides.image.drive.${item.uuid.uuid}'),
            width: double.infinity,
            mainAxisAlignment: MainAxisAlignment.start,
            leading: const Icon(LucideIcons.image, size: 16),
            onPressed: () => _close(item),
            child: Flexible(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      );
    }
    return ShadDialog(
      key: const ValueKey<String>('dialog.slides.imageDrive'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.imageDriveDialogTitle),
      constraints: BoxConstraints(maxWidth: width < 520 ? width - 32 : 480),
      actions: [
        ShadButton.outline(
          onPressed: () => _close(null),
          child: Text(la.actionCancel),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInput(
            key: const ValueKey<String>('slides.image.drive.search'),
            controller: _search,
            placeholder: Text(l.imageDriveSearch),
            leading: const Icon(LucideIcons.search, size: 16),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 250),
                () => unawaited(_find()),
              );
            },
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: body,
          ),
        ],
      ),
    );
  }
}
