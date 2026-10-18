import 'dart:async';

import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/slides_l10n.dart';

/// The audience link of a session (Slides 10 §5.2): the deck's present
/// route with `view=audience` on the Slides app's URL. It is user-bound —
/// only the presenter's own account (or followers) can join.
String audienceLink(ShellServices s, String itemUuid, String sessionId) {
  final base = s.urls.apps[WonkyAppKind.slides] ?? '/slides/';
  final path = s.config.itemPath(itemUuid).replaceFirst(RegExp('^/'), '');
  return '$base$path/present?view=audience&session=$sessionId';
}

/// *Open on another device…* (`slides.present.openOnAnotherDevice`, 10
/// §5.2): the audience link as a QR code and text with *Copy link*. The
/// link is opened by the user on the other device or browser — the app
/// never opens a window.
Future<void> showOpenOnDeviceDialog(
  BuildContext context, {
  required String link,
  required bool online,
}) => showShadDialog<void>(
  context: context,
  builder: (_) => OpenOnDeviceDialog(link: link, online: online),
);

class OpenOnDeviceDialog extends StatefulWidget {
  const OpenOnDeviceDialog({super.key, required this.link, this.online = true});

  final String link;
  final bool online;

  @override
  State<OpenOnDeviceDialog> createState() => _OpenOnDeviceDialogState();
}

class _OpenOnDeviceDialogState extends State<OpenOnDeviceDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  bool _copied = false;

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
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Map<String, Object?> describe() {
    final l = slidesL10n(context);
    return {
      'title': l.presentOpenOnDeviceTitle,
      'description': l.presentOpenOnDeviceBody,
      'fields': [
        {
          'id': 'link',
          'label': l.presentAudienceLink,
          'type': 'text',
          'value': widget.link,
          'readOnly': true,
        },
      ],
      'buttons': [
        {'id': 'copy', 'label': l.presentCopyLink},
        {'id': 'done', 'label': l.presentDone, 'primary': true},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) => false;

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'copy':
        unawaited(_copy());
        return true;
      case 'done' || 'cancel':
        Navigator.of(context).pop();
        return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = slidesL10n(context);
    return ShadDialog(
      key: const ValueKey<String>('dialog.slides.openOnDevice'),
      closeIcon: const WonkyDialogCloseButton(),
      constraints: const BoxConstraints(maxWidth: 440),
      title: Text(l.presentOpenOnDeviceTitle),
      description: Text(l.presentOpenOnDeviceBody),
      actions: [
        ShadButton.outline(
          key: const ValueKey<String>('dialog.slides.openOnDevice.copy'),
          leading: Icon(
            _copied ? LucideIcons.check : LucideIcons.copy,
            size: 16,
          ),
          onPressed: () => unawaited(_copy()),
          child: Text(_copied ? l.presentLinkCopied : l.presentCopyLink),
        ),
        ShadButton(
          key: const ValueKey<String>('dialog.slides.openOnDevice.done'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.presentDone),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.online)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ShadAlert.destructive(
                  icon: const Icon(LucideIcons.wifiOff),
                  title: Text(l.presentOfflineNoDevices),
                ),
              ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // QR codes need a light quiet zone in both themes.
                  color: const Color(0xffffffff),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.border),
                ),
                child: QrCodeView(
                  key: const ValueKey<String>('dialog.slides.openOnDevice.qr'),
                  data: widget.link,
                  size: 180,
                  semanticLabel: l.presentQrLabel,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              widget.link,
              key: const ValueKey<String>('dialog.slides.openOnDevice.link'),
              style: theme.textTheme.small.copyWith(
                fontFamily: 'JetBrains Mono',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(l.presentOpenOnDeviceHint, style: theme.textTheme.muted),
          ],
        ),
      ),
    );
  }
}

/// A QR code of [data] (error correction M), drawn black on white.
class QrCodeView extends StatelessWidget {
  const QrCodeView({
    super.key,
    required this.data,
    this.size = 160,
    this.semanticLabel,
  });

  final String data;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    QrImage? image;
    try {
      image = QrImage(
        QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
      );
    } on Object {
      image = null;
    }
    return Semantics(
      image: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: image == null ? null : CustomPaint(painter: _QrPainter(image)),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    final n = image.moduleCount;
    final cell = size.width / n;
    final paint = Paint()..color = const Color(0xff000000);
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (image.isDark(r, c)) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell + 0.3, cell + 0.3),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => !identical(old.image, image);
}
