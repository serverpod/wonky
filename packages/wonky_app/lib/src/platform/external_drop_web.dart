import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'external_drop.dart';

ExternalDropSource createExternalDropSource() => _WebDropSource();

/// Browser drag-and-drop events on the window.
class _WebDropSource implements ExternalDropSource {
  JSFunction? _over;
  JSFunction? _leave;
  JSFunction? _drop;

  bool Function(Offset globalPosition, ExternalDragKind kind)? _onOver;
  VoidCallback? _onLeave;
  void Function(ExternalDrop drop)? _onDrop;

  @override
  void attach({
    required bool Function(Offset globalPosition, ExternalDragKind kind) onOver,
    required VoidCallback onLeave,
    required void Function(ExternalDrop drop) onDrop,
  }) {
    detach();
    _onOver = onOver;
    _onLeave = onLeave;
    _onDrop = onDrop;
    _over = _handleOver.toJS;
    _leave = _handleLeave.toJS;
    _drop = _handleDrop.toJS;
    web.window.addEventListener('dragenter', _over);
    web.window.addEventListener('dragover', _over);
    web.window.addEventListener('dragleave', _leave);
    web.window.addEventListener('drop', _drop);
  }

  @override
  void detach() {
    if (_over != null) {
      web.window.removeEventListener('dragenter', _over);
      web.window.removeEventListener('dragover', _over);
      web.window.removeEventListener('dragleave', _leave);
      web.window.removeEventListener('drop', _drop);
    }
    _over = _leave = _drop = null;
    _onOver = null;
    _onLeave = null;
    _onDrop = null;
  }

  static ExternalDragKind? _kindOf(web.DataTransfer? transfer) {
    if (transfer == null) return null;
    final types = transfer.types.toDart.map((t) => t.toDart).toSet();
    if (types.contains('Files')) return ExternalDragKind.files;
    if (types.contains('text/html') ||
        types.contains('text/plain') ||
        types.contains('text/uri-list')) {
      return ExternalDragKind.text;
    }
    return null;
  }

  static Offset _position(web.DragEvent event) =>
      Offset(event.clientX.toDouble(), event.clientY.toDouble());

  void _handleOver(web.DragEvent event) {
    // Never let the browser open the dropped file in this tab.
    event.preventDefault();
    final transfer = event.dataTransfer;
    final kind = _kindOf(transfer);
    final accepted =
        kind != null && (_onOver?.call(_position(event), kind) ?? false);
    transfer?.dropEffect = accepted ? 'copy' : 'none';
  }

  void _handleLeave(web.DragEvent event) {
    // `dragleave` also fires when moving between child elements; only a
    // leave to outside the window (no related target) ends the hover.
    if (event.relatedTarget == null) _onLeave?.call();
  }

  void _handleDrop(web.DragEvent event) {
    event.preventDefault();
    final transfer = event.dataTransfer;
    final onDrop = _onDrop;
    _onLeave?.call();
    if (transfer == null || onDrop == null) return;
    final position = _position(event);
    final plain = transfer.getData('text/plain');
    final html = transfer.getData('text/html');
    final fileList = transfer.files;
    final files = <web.File>[
      for (var i = 0; i < fileList.length; i += 1) ?fileList.item(i),
    ];
    if (files.isEmpty) {
      onDrop(
        ExternalDrop(
          globalPosition: position,
          plainText: plain.isEmpty ? null : plain,
          html: html.isEmpty ? null : html,
        ),
      );
      return;
    }
    unawaited(
      _readFiles(files).then((read) {
        onDrop(ExternalDrop(globalPosition: position, files: read));
      }),
    );
  }

  static Future<List<DroppedFile>> _readFiles(List<web.File> files) async {
    final out = <DroppedFile>[];
    for (final file in files) {
      try {
        final buffer = await file.arrayBuffer().toDart;
        out.add(
          DroppedFile(
            name: file.name,
            mimeType: file.type,
            bytes: Uint8List.view(buffer.toDart),
          ),
        );
      } catch (_) {
        // Unreadable (a folder, a revoked file): skip it.
      }
    }
    return out;
  }
}
