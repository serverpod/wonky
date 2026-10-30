import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

/// A user avatar: the picture when [imageUrl] is set, otherwise initials on
/// [color]. Optionally ringed (presence color).
class WonkyAvatar extends StatelessWidget {
  const WonkyAvatar({
    super.key,
    required this.name,
    required this.color,
    this.imageUrl,
    this.size = 28,
    this.ringColor,
    this.icon,
    this.semanticLabel,
  });

  final String name;

  /// Background for the initials.
  final Color color;
  final String? imageUrl;
  final double size;
  final Color? ringColor;

  /// Replaces the initials (e.g. a bot icon for MCP/AI participants).
  final IconData? icon;
  final String? semanticLabel;

  /// Up to two initials from [name] ("Anna Berg" → "AB", "bo@x.io" → "B").
  static String initialsOf(String name) {
    final clean = name.contains('@') ? name.split('@').first : name;
    final parts = clean
        .split(RegExp(r'[\s._-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  /// Width of the ring and its gap to the avatar (drawn inside [size]).
  static const double _ringWidth = 2;
  static const double _ringGap = 1.5;

  @override
  Widget build(BuildContext context) {
    final fg = ShadColorScheme.contrastingForeground(color);
    // With a ring, the whole avatar (ring included) is [size] wide, so hosts
    // that size it (e.g. the presence stack) don't clip the ring.
    final inner = ringColor == null ? size : size - 2 * (_ringWidth + _ringGap);
    final fallback = Container(
      width: inner,
      height: inner,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: icon != null
          ? Icon(icon, size: inner * 0.55, color: fg)
          : Text(
              initialsOf(name),
              textAlign: TextAlign.center,
              // Centered on the glyphs: no inherited letter spacing (which
              // pads one side) and no extra line leading.
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              // The app font: the inherited default text style may carry no
              // family (then the browser's default font, wider, is used).
              style: ShadTheme.of(context).textTheme.small.copyWith(
                color: fg,
                fontSize: inner * 0.4,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                height: 1,
                leadingDistribution: TextLeadingDistribution.even,
              ),
            ),
    );
    Widget avatar = imageUrl == null || imageUrl!.isEmpty
        ? fallback
        : ShadAvatar(imageUrl, size: Size.square(inner), fallback: fallback);
    if (ringColor != null) {
      avatar = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor!, width: _ringWidth),
        ),
        child: avatar,
      );
    }
    return Semantics(
      label: semanticLabel ?? name,
      image: true,
      child: ExcludeSemantics(child: avatar),
    );
  }
}
