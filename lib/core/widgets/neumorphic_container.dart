import 'package:flutter/material.dart';
import '../theme/pulso_theme_extension.dart';

enum NeumorphicState { raised, flat, inset }

/// Dual-shadow neumorphic surface — design spec section 4.
///
/// All color and shadow values come from [ThemeData] / [PulsoThemeExtension]
/// so dark-mode and future palette changes require zero widget-level changes.
///
/// Every variant wraps its output in [RepaintBoundary] so parent animations
/// (route transitions, scrolling) reuse the cached GPU texture instead of
/// re-executing [CustomPainter.paint] on every frame.
class NeumorphicContainer extends StatelessWidget {
  const NeumorphicContainer({
    super.key,
    required this.child,
    this.state = NeumorphicState.raised,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  final Widget child;
  final NeumorphicState state;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final pulso = context.pulso;

    final content = padding != null ? Padding(padding: padding!, child: child) : child;

    final Widget surface;

    switch (state) {
      case NeumorphicState.raised:
        surface = Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: pulso.shadowLight,
                offset: const Offset(-6, -6),
                blurRadius: pulso.shadowBlur,
              ),
              BoxShadow(
                color: pulso.shadowDark,
                offset: const Offset(6, 6),
                blurRadius: pulso.shadowBlur,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: content,
          ),
        );

      case NeumorphicState.flat:
        surface = Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: content,
          ),
        );

      case NeumorphicState.inset:
        surface = SizedBox(
          width: width,
          height: height,
          child: Container(
            margin: margin,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: CustomPaint(
                painter: _InsetShadowPainter(
                  backgroundColor: pulso.surfaceInset,
                  lightColor: pulso.shadowLight,
                  darkColor: pulso.shadowDark,
                  borderRadius: borderRadius,
                  blur: pulso.shadowBlur,
                ),
                child: content,
              ),
            ),
          ),
        );
    }

    return RepaintBoundary(child: surface);
  }
}

/// Inner neumorphic shadow painter.
/// Paths are cached per [Size] — rebuilt only on resize, not every frame.
class _InsetShadowPainter extends CustomPainter {
  _InsetShadowPainter({
    required this.backgroundColor,
    required this.lightColor,
    required this.darkColor,
    required this.borderRadius,
    required this.blur,
  });

  final Color backgroundColor;
  final Color lightColor;
  final Color darkColor;
  final double borderRadius;
  final double blur;

  static const double _offset = 6.0;

  Size? _cachedSize;
  Path? _darkPath;
  Path? _lightPath;

  void _rebuildPaths(Size size) {
    const pad = 600.0;
    final huge = Rect.fromLTWH(-pad, -pad, size.width + pad * 2, size.height + pad * 2);
    final r = Radius.circular(borderRadius);

    _darkPath = Path()
      ..addRect(huge)
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).shift(const Offset(_offset, _offset)),
        r,
      ))
      ..fillType = PathFillType.evenOdd;

    _lightPath = Path()
      ..addRect(huge)
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).shift(const Offset(-_offset, -_offset)),
        r,
      ))
      ..fillType = PathFillType.evenOdd;

    _cachedSize = size;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rrect, Paint()..color = backgroundColor);

    if (_cachedSize != size) _rebuildPaths(size);

    final sigma = blur / 2;
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPath(_darkPath!,
        Paint()..color = darkColor..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma));
    canvas.drawPath(_lightPath!,
        Paint()..color = lightColor..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetShadowPainter old) =>
      old.backgroundColor != backgroundColor ||
      old.lightColor != lightColor ||
      old.darkColor != darkColor ||
      old.borderRadius != borderRadius;
}
