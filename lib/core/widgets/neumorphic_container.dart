import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NeumorphicState { raised, flat, inset }

/// Dual-shadow neumorphic surface — design spec section 4.
///
/// Raised: light shadow top-left, dark shadow bottom-right (element pops out).
/// Inset:  dark shadow top-left, light shadow bottom-right (element pressed in).
/// Flat:   no shadow, same base background.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shadowLight = isDark ? AppColors.shadowLightD : AppColors.shadowLightL;
    final shadowDark = isDark ? AppColors.shadowDarkD : AppColors.shadowDarkL;
    final blur = isDark ? 12.0 : 14.0;

    final paddingWidget =
        padding != null ? Padding(padding: padding!, child: child) : child;

    switch (state) {
      case NeumorphicState.raised:
        final bg = isDark ? AppColors.surfaceRaisedD : AppColors.surfaceRaisedL;
        return Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: shadowLight,
                offset: const Offset(-6, -6),
                blurRadius: blur,
              ),
              BoxShadow(
                color: shadowDark,
                offset: const Offset(6, 6),
                blurRadius: blur,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: paddingWidget,
          ),
        );

      case NeumorphicState.flat:
        final bg = isDark ? AppColors.surfaceD : AppColors.surfaceL;
        return Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: paddingWidget,
          ),
        );

      case NeumorphicState.inset:
        final bg = isDark ? AppColors.surfaceInsetD : AppColors.surfaceInsetL;
        return SizedBox(
          width: width,
          height: height,
          child: Container(
            margin: margin,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: CustomPaint(
                painter: _InsetShadowPainter(
                  backgroundColor: bg,
                  lightColor: shadowLight,
                  darkColor: shadowDark,
                  borderRadius: borderRadius,
                  blur: blur,
                ),
                child: paddingWidget,
              ),
            ),
          ),
        );
    }
  }
}

/// Paints inner neumorphic shadows using the "donut path" technique:
/// a large outer rect minus a shifted inner rrect creates the edge shadow
/// that, after clipping, looks like a shadow coming from inside the surface.
class _InsetShadowPainter extends CustomPainter {
  const _InsetShadowPainter({
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

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    // Fill base background
    canvas.drawRRect(rrect, Paint()..color = backgroundColor);

    canvas.save();
    canvas.clipRRect(rrect);

    // Dark inner shadow from top-left (gives the "pressed in" feel)
    _drawInnerShadow(canvas, size, darkColor, const Offset(_offset, _offset));
    // Light inner highlight from bottom-right
    _drawInnerShadow(canvas, size, lightColor, const Offset(-_offset, -_offset));

    canvas.restore();
  }

  void _drawInnerShadow(Canvas canvas, Size size, Color color, Offset dir) {
    const padding = 600.0;
    final huge = Rect.fromLTWH(-padding, -padding, size.width + padding * 2, size.height + padding * 2);
    final shifted = RRect.fromRectAndRadius(
      (Offset.zero & size).shift(dir),
      Radius.circular(borderRadius),
    );

    // Donut: large rect minus the shifted inner rrect — only the edge inside
    // the clip boundary is visible, creating the inner shadow ring.
    final path = Path()
      ..addRect(huge)
      ..addRRect(shifted)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
    );
  }

  @override
  bool shouldRepaint(_InsetShadowPainter old) =>
      old.backgroundColor != backgroundColor ||
      old.lightColor != lightColor ||
      old.darkColor != darkColor;
}
