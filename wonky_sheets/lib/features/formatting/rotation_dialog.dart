import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import '../number_format/mcp_dialog_state.dart';

/// Custom text rotation angle (04 §11.21): a −90…90° stepper with a dial
/// preview (drag the dial or use the arrow keys). Returns the angle.
Future<int?> showRotationAngleDialog(BuildContext context, int current) =>
    showShadDialog<int>(
      context: context,
      builder: (_) =>
          RotationAngleDialog(initial: current == 255 ? 0 : current),
    );

class RotationAngleDialog extends StatefulWidget {
  const RotationAngleDialog({super.key, required this.initial});

  final int initial;

  @override
  State<RotationAngleDialog> createState() => _RotationAngleDialogState();
}

class _RotationAngleDialogState extends McpDialogState<RotationAngleDialog> {
  late int _angle = widget.initial.clamp(-90, 90);

  void _set(num v) => setState(() => _angle = v.round().clamp(-90, 90));

  @override
  Map<String, Object?> describe() => {
    'title': 'Custom angle',
    'fields': [
      {'id': 'angle', 'label': 'Angle', 'type': 'number', 'value': _angle},
    ],
    'buttons': [
      {'id': 'cancel', 'label': 'Cancel'},
      {'id': 'apply', 'label': 'Apply'},
    ],
  };

  @override
  bool setField(String id, Object? value) {
    final v = value is num ? value : num.tryParse('$value');
    if (id != 'angle' || v == null || v < -90 || v > 90) return false;
    _set(v);
    return true;
  }

  @override
  bool press(String buttonId) {
    if (buttonId == 'cancel') {
      close();
      return true;
    }
    if (buttonId == 'apply') {
      close(_angle);
      return true;
    }
    return false;
  }

  void _drag(Offset local, Size size) {
    // The dial is a half circle opening to the right: angle from the
    // horizontal through the centre of its left edge.
    final c = Offset(size.width * 0.15, size.height / 2);
    final d = local - c;
    if (d.dx <= 0 && d.dy.abs() < 1) return;
    final a = -math.atan2(d.dy, math.max(0.0001, d.dx)) * 180 / math.pi;
    _set(a);
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => close(),
        const SingleActivator(LogicalKeyboardKey.enter): () => close(_angle),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.rotation'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.dialogRotationTitle),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.rotation.cancel'),
            onPressed: () => close(),
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.rotation.apply'),
            onPressed: () => close(_angle),
            child: Text(l.dialogApply),
          ),
        ],
        child: SizedBox(
          width: 300,
          child: Row(
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  const size = Size(120, 120);
                  return Semantics(
                    slider: true,
                    value: '$_angle°',
                    label: l.dialogRotationLabel,
                    child: GestureDetector(
                      onPanDown: (d) => _drag(d.localPosition, size),
                      onPanUpdate: (d) => _drag(d.localPosition, size),
                      child: CustomPaint(
                        size: size,
                        painter: _DialPainter(
                          angle: _angle,
                          track: theme.colorScheme.border,
                          hand: theme.colorScheme.primary,
                          text: theme.colorScheme.foreground,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.dialogRotationLabel, style: theme.textTheme.small),
                    const SizedBox(height: 6),
                    WonkyNumberStepper(
                      key: const ValueKey<String>('dialog.rotation.angle'),
                      value: _angle,
                      min: -90,
                      max: 90,
                      step: 5,
                      suffix: '°',
                      semanticLabel: l.dialogRotationLabel,
                      onChanged: _set,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.angle,
    required this.track,
    required this.hand,
    required this.text,
  });

  final int angle;
  final Color track;
  final Color hand;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.15, size.height / 2);
    final r = size.width * 0.8;
    final t = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi,
      false,
      t,
    );
    for (var a = -90; a <= 90; a += 45) {
      final rad = -a * math.pi / 180;
      final p = c + Offset(math.cos(rad), math.sin(rad)) * r;
      canvas.drawCircle(p, 2, Paint()..color = track);
    }
    final rad = -angle * math.pi / 180;
    final dir = Offset(math.cos(rad), math.sin(rad));
    canvas.drawLine(
      c,
      c + dir * r,
      Paint()
        ..color = hand
        ..strokeWidth = 2,
    );
    canvas.drawCircle(c + dir * r, 5, Paint()..color = hand);
    // "Text" along the hand.
    final tp = TextPainter(
      text: TextSpan(
        text: 'Text',
        style: TextStyle(color: text, fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rad);
    tp.paint(canvas, Offset(8, -tp.height - 2));
    canvas.restore();
    tp.dispose();
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.angle != angle || old.hand != hand || old.track != track;
}
