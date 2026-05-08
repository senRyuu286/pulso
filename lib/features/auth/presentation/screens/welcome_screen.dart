import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceD : AppColors.surfaceL;
    final heroColor = isDark ? AppColors.surfaceRaisedD : AppColors.textPrimaryL;
    final heroHeight = MediaQuery.of(context).size.height * 0.4;
    final logoTop = heroHeight - 56;
    final logoAsset = Image.asset(
      'assets/logo/logo-light.png',
      fit: BoxFit.contain,
    );
    final heroRadius = BorderRadius.only(
      bottomLeft: Radius.circular(120),
      bottomRight: Radius.circular(120),
    );
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const buttonStackHeight = 52 + 14 + 52;
    final textTop = logoTop + 112 + 16;
    final textBottom = bottomInset + 48 + buttonStackHeight + 16;

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: ClipRRect(
              borderRadius: heroRadius,
              child: Stack(
                children: [
                  Container(color: heroColor),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color(0x0FFFFFFF),
                          Color(0x00000000),
                        ],
                        center: Alignment(0.0, -0.3),
                        radius: 1.2,
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: Size.infinite,
                    painter: _HeroArcPainter(),
                  ),
                  const SafeArea(
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: logoTop,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: AppColors.surfaceL,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.dividerD : AppColors.dividerL,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: logoAsset,
                ),
              ),
            ),
          ),
          Positioned(
            top: textTop,
            left: 24,
            right: 24,
            bottom: textBottom,
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pulso',
                    style: AppTextStyles.headline.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryD
                          : AppColors.textPrimaryL,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A living pulse of\nyour community',
                    style: AppTextStyles.body.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryD
                          : AppColors.textSecondaryL,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 80),
                    PrimaryButton(
                      label: 'Sign In >',
                      onPressed: () => context.go('/login'),
                    ),
                    const SizedBox(height: 14),
                    _OutlinedButton(
                      label: 'Create Account',
                      onPressed: () => context.go('/register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = const Color(0x18FFFFFF);
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = const Color(0x10FFFFFF);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 140),
      _degreesToRadians(190),
      _degreesToRadians(160),
      false,
      paint1,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 220),
      _degreesToRadians(190),
      _degreesToRadians(160),
      false,
      paint2,
    );
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _OutlinedButton extends StatefulWidget {
  const _OutlinedButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_OutlinedButton> createState() => _OutlinedButtonState();
}

class _OutlinedButtonState extends State<_OutlinedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;
    final surface = isDark ? AppColors.surfaceD : AppColors.surfaceL;

    final raisedShadows = isDark
        ? [
            const BoxShadow(
              color: Color(0xFF2E231B),
              offset: Offset(-5, -5),
              blurRadius: 10,
              spreadRadius: 0,
            ),
            const BoxShadow(
              color: Color(0xFF0E0907),
              offset: Offset(5, 5),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ]
        : [
            const BoxShadow(
              color: Color(0xFFFFFFFF),
              offset: Offset(-5, -5),
              blurRadius: 12,
              spreadRadius: 0,
            ),
            const BoxShadow(
              color: Color(0xFFC8BDB4),
              offset: Offset(5, 5),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ];

    final insetShadows = isDark
        ? [
            const BoxShadow(
              color: Color(0xFF2E231B),
              offset: Offset(3, 3),
              blurRadius: 6,
              blurStyle: BlurStyle.inner,
            ),
            const BoxShadow(
              color: Color(0xFF0E0907),
              offset: Offset(-3, -3),
              blurRadius: 6,
              blurStyle: BlurStyle.inner,
            ),
          ]
        : [
            const BoxShadow(
              color: Color(0xFFFFFFFF),
              offset: Offset(3, 3),
              blurRadius: 6,
              blurStyle: BlurStyle.inner,
            ),
            const BoxShadow(
              color: Color(0xFFC8BDB4),
              offset: Offset(-3, -3),
              blurRadius: 6,
              blurStyle: BlurStyle.inner,
            ),
          ];

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: Duration(milliseconds: _isPressed ? 80 : 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: Duration(milliseconds: _isPressed ? 80 : 150),
          curve: Curves.easeOut,
          height: 52,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isPressed ? insetShadows : raisedShadows,
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.title.copyWith(color: primary),
          ),
        ),
      ),
    );
  }
}
