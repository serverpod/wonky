import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Whether the platform shows PDFs inline (web: the browser's viewer).
const bool canPreviewPdfInline = true;

/// One platform-view factory for every viewer (a factory can never be
/// unregistered, so one per PDF would leak, W-20); the `<iframe>` source
/// comes as the creation parameter.
const _viewType = 'wonky-pdf-view';
bool _registered = false;

/// The shown viewers' frames, by blob URL (printing uses the shown one).
final Map<String, web.HTMLIFrameElement> _frames = {};

void _ensureFactory() {
  if (_registered) return;
  _registered = true;
  ui_web.platformViewRegistry.registerViewFactory(_viewType, (
    int id, {
    Object? params,
  }) {
    final p = params! as Map<Object?, Object?>;
    final url = p['url']! as String;
    final frame = web.HTMLIFrameElement()
      ..src = '$url${p['fragment']}'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    _frames[url] = frame;
    return frame;
  });
}

String _blobUrl(Uint8List bytes) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  return web.URL.createObjectURL(blob);
}

/// The PDF in the browser's built-in viewer, inside the app: an `<iframe>`
/// platform view, no new tab or window (suite 03 §1). [thumbnails] shows
/// the viewer's page panel, [fitPage] fits whole pages (else the width),
/// [page] (1-based) opens at that page. [desktopTitle] and [desktopHint]
/// are the desktop summary's texts.
class PdfView extends StatefulWidget {
  const PdfView({
    super.key,
    required this.bytes,
    required this.desktopTitle,
    required this.desktopHint,
    this.page,
    this.thumbnails = false,
    this.fitPage = false,
  });

  final Uint8List bytes;
  final String desktopTitle;
  final String desktopHint;
  final int? page;
  final bool thumbnails;
  final bool fitPage;

  @override
  State<PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> {
  late String _url;

  @override
  void initState() {
    super.initState();
    _ensureFactory();
    _url = _blobUrl(widget.bytes);
  }

  @override
  void didUpdateWidget(PdfView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      _release(_url);
      _url = _blobUrl(widget.bytes);
    }
  }

  @override
  void dispose() {
    _release(_url);
    super.dispose();
  }

  static void _release(String url) {
    _frames.remove(url);
    web.URL.revokeObjectURL(url);
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page == null ? '' : '&page=${widget.page}';
    final fragment =
        '#toolbar=1&navpanes=${widget.thumbnails ? 1 : 0}'
        '&view=${widget.fitPage ? 'Fit' : 'FitH'}$page';
    return HtmlElementView(
      key: ValueKey<String>(_url),
      viewType: _viewType,
      creationParams: {'url': _url, 'fragment': fragment},
    );
  }
}

web.HTMLIFrameElement? _printFrame;
String? _printUrl;

/// Prints [bytes] through the browser's print dialog in this tab: the shown
/// viewer's frame, else a hidden `<iframe>` that is removed (and its URL
/// revoked) after printing or with the next print (W-20).
Future<bool> printPdf(Uint8List bytes, {required String title}) async {
  for (final shown in _frames.values.toList().reversed) {
    if (!shown.isConnected) continue;
    try {
      shown.contentWindow?.focus();
      shown.contentWindow?.print();
      return true;
    } catch (_) {
      break; // Fall back to a hidden frame.
    }
  }
  _removePrintFrame();
  final url = _blobUrl(bytes);
  final frame = web.HTMLIFrameElement()
    ..title = title
    ..style.position = 'fixed'
    ..style.right = '0'
    ..style.bottom = '0'
    ..style.width = '0'
    ..style.height = '0'
    ..style.border = '0'
    ..src = url;
  _printFrame = frame;
  _printUrl = url;
  frame.onload = ((web.Event _) {
    final window = frame.contentWindow;
    window?.addEventListener(
      'afterprint',
      ((web.Event _) {
        if (identical(_printFrame, frame)) _removePrintFrame();
      }).toJS,
    );
    window?.focus();
    window?.print();
  }).toJS;
  web.document.body?.append(frame);
  return true;
}

void _removePrintFrame() {
  _printFrame?.remove();
  _printFrame = null;
  final url = _printUrl;
  if (url != null) web.URL.revokeObjectURL(url);
  _printUrl = null;
}
