import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/write_l10n.dart';
import 'image_services.dart';

/// Opens the platform picker for images (png, jpg, gif, webp; up to 20).
/// Rejected files are reported through [onRejected], with the reason in [l]
/// (English when omitted).
Future<List<PickedImage>> pickImageFiles({
  bool multiple = true,
  void Function(String name, String reason)? onRejected,
  WriteLocalizations? l,
}) async {
  final strings = l ?? writeL10nEnglish;
  final files = multiple
      ? await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ImageRules.extensions,
          dialogTitle: strings.imagePickMultipleTitle,
        )
      : [
          ?await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: ImageRules.extensions,
            dialogTitle: strings.imagePickSingleTitle,
          ),
        ];
  final out = <PickedImage>[];
  for (final f in files.take(20)) {
    final bytes = await f.readAsBytes();
    try {
      final mime = ImageRules.validate(f.name, bytes);
      out.add(PickedImage(name: f.name, bytes: bytes, mimeType: mime));
    } on ImageRejected catch (e) {
      onRejected?.call(f.name, e.messageIn(strings));
    }
  }
  return out;
}

/// Result of the image-by-URL dialog.
typedef ImageUrlResult = ({String url, String alt});

/// Insert image by URL (`write.dialog.imageUrl`, Write 05 §12.1). [title]
/// and [action] default to "Insert image by URL" / "Insert".
Future<ImageUrlResult?> showImageUrlDialog(
  BuildContext context, {
  String? title,
  String? action,
}) => showShadDialog<ImageUrlResult>(
  context: context,
  builder: (_) => ImageUrlDialog(title: title, action: action),
);

class ImageUrlDialog extends StatefulWidget {
  const ImageUrlDialog({super.key, this.title, this.action});

  /// Defaults to "Insert image by URL".
  final String? title;

  /// Defaults to "Insert".
  final String? action;

  @override
  State<ImageUrlDialog> createState() => _ImageUrlDialogState();
}

enum _Preview { none, loading, loaded, failed }

class _ImageUrlDialogState extends State<ImageUrlDialog> {
  final _url = TextEditingController();
  final _alt = TextEditingController();
  final _urlFocus = FocusNode();
  String? _error;
  String? _previewUrl;
  _Preview _preview = _Preview.none;
  bool _insertAnyway = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _urlFocus.addListener(() {
      if (!_urlFocus.hasFocus) _validate(showError: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _url.dispose();
    _alt.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  String? _problem(String url) {
    final l = writeL10n(context);
    if (url.isEmpty) return l.imageUrlEmpty;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return l.imageUrlInvalid;
    if (uri.scheme != 'https') return l.imageUrlNeedsHttps;
    return null;
  }

  void _validate({bool showError = false}) {
    final url = _url.text.trim();
    final problem = _problem(url);
    setState(() {
      _error = showError || url.isNotEmpty ? problem : null;
      if (problem == null && url != _previewUrl) {
        _previewUrl = url;
        _preview = _Preview.loading;
        _insertAnyway = false;
      } else if (problem != null) {
        _previewUrl = null;
        _preview = _Preview.none;
      }
    });
  }

  bool get _canInsert =>
      _problem(_url.text.trim()) == null &&
      (_preview == _Preview.loaded || _insertAnyway);

  void _submit() {
    if (!_canInsert) return;
    Navigator.of(context).pop((url: _url.text.trim(), alt: _alt.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return ShadDialog(
      key: const ValueKey<String>('write.dialog.imageUrl'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(widget.title ?? l.imageUrlTitle),
      constraints: const BoxConstraints(maxWidth: 520),
      actions: [
        ShadButton.outline(
          key: const ValueKey<String>('write.dialog.imageUrl.cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        ShadButton(
          key: const ValueKey<String>('write.dialog.imageUrl.insert'),
          enabled: _canInsert,
          onPressed: _submit,
          child: Text(widget.action ?? l.commonInsert),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: Text(l.imageUrlLabel, style: theme.textTheme.small),
          ),
          const SizedBox(height: 6),
          Semantics(
            label: l.imageUrlLabel,
            child: ShadInput(
              key: const ValueKey<String>('write.dialog.imageUrl.url'),
              controller: _url,
              focusNode: _urlFocus,
              autofocus: true,
              placeholder: const Text('https://example.com/picture.png'),
              leading: Icon(
                LucideIcons.link,
                size: 16,
                color: cs.mutedForeground,
              ),
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), _validate);
              },
              onSubmitted: (_) {
                _validate(showError: true);
                _submit();
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: theme.textTheme.small.copyWith(color: cs.destructive),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: cs.muted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Semantics(
              label: l.imagePreviewSemantic,
              child: _previewWidget(context),
            ),
          ),
          if (_preview == _Preview.failed) ...[
            const SizedBox(height: 8),
            ShadCheckbox(
              key: const ValueKey<String>('write.dialog.imageUrl.anyway'),
              value: _insertAnyway,
              onChanged: (v) => setState(() => _insertAnyway = v),
              label: Text(l.imageInsertAnyway),
            ),
          ],
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Text(l.imageAltText, style: theme.textTheme.small),
          ),
          const SizedBox(height: 6),
          Semantics(
            label: l.imageAltText,
            child: ShadTextarea(
              key: const ValueKey<String>('write.dialog.imageUrl.alt'),
              controller: _alt,
              minHeight: 64,
              maxHeight: 120,
              maxLength: 500,
              placeholder: Text(l.imageAltPlaceholder),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.imageAltHint,
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _previewWidget(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    final url = _previewUrl;
    if (url == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.image,
              size: 28,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: 8),
            Text(l.imagePreviewEmpty, style: theme.textTheme.muted),
          ],
        ),
      );
    }
    return Image.network(
      url,
      key: ValueKey<String>(url),
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, sync) {
        if (frame != null &&
            _preview != _Preview.loaded &&
            _previewUrl == url) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _previewUrl == url) {
              setState(() => _preview = _Preview.loaded);
            }
          });
        }
        return frame == null ? const Center(child: ShadSpinner()) : child;
      },
      errorBuilder: (context, error, stack) {
        if (_preview != _Preview.failed && _previewUrl == url) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _previewUrl == url) {
              setState(() => _preview = _Preview.failed);
            }
          });
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.imageOff,
                size: 28,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(height: 8),
              Text(l.imagePreviewFailed, style: theme.textTheme.muted),
            ],
          ),
        );
      },
    );
  }
}

/// Result of the alt text dialog.
typedef ImageAltResult = ({String alt, String? title});

/// Image alt text (`write.dialog.imageAlt`, Write 05 §12.2).
Future<ImageAltResult?> showImageAltDialog(
  BuildContext context, {
  String alt = '',
  String? title,
}) => showShadDialog<ImageAltResult>(
  context: context,
  builder: (_) => ImageAltDialog(alt: alt, title: title),
);

class ImageAltDialog extends StatefulWidget {
  const ImageAltDialog({super.key, this.alt = '', this.title});

  final String alt;
  final String? title;

  @override
  State<ImageAltDialog> createState() => _ImageAltDialogState();
}

class _ImageAltDialogState extends State<ImageAltDialog> {
  late final _alt = TextEditingController(text: widget.alt);
  late final _title = TextEditingController(text: widget.title ?? '');

  @override
  void dispose() {
    _alt.dispose();
    _title.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop((
    alt: _alt.text.trim(),
    title: _title.text.trim().isEmpty ? null : _title.text.trim(),
  ));

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    return ShadDialog(
      key: const ValueKey<String>('write.dialog.imageAlt'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.imageAltText),
      description: Text(l.imageAltDescription),
      constraints: const BoxConstraints(maxWidth: 460),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        ShadButton(
          key: const ValueKey<String>('write.dialog.imageAlt.save'),
          onPressed: _save,
          child: Text(l.commonSave),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: Text(l.imageAltText, style: theme.textTheme.small),
          ),
          const SizedBox(height: 6),
          ListenableBuilder(
            listenable: _alt,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Semantics(
                  label: l.imageAltText,
                  child: ShadTextarea(
                    key: const ValueKey<String>('write.dialog.imageAlt.alt'),
                    controller: _alt,
                    autofocus: true,
                    maxLength: 500,
                    minHeight: 80,
                    maxHeight: 160,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.imageAltCount(_alt.text.length, 500),
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Text(l.imageTitleOptional, style: theme.textTheme.small),
          ),
          const SizedBox(height: 6),
          Semantics(
            label: l.imageTitleOptional,
            child: ShadInput(
              key: const ValueKey<String>('write.dialog.imageAlt.title'),
              controller: _title,
              placeholder: Text(l.imageTitlePlaceholder),
              onSubmitted: (_) => _save(),
            ),
          ),
        ],
      ),
    );
  }
}
