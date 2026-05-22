import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (widget.onPressed == null || widget.isLoading) {
      return;
    }
    setState(() {
      _isPressed = pressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final surface = widget.onPressed == null || widget.isLoading ? 0.6 : 1.0;

    final decoration = BoxDecoration(
      color: primary,
      borderRadius: BorderRadius.circular(12),
    );

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onPressed == null || widget.isLoading
          ? null
          : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: Duration(milliseconds: _isPressed ? 80 : 150),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: surface,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: Duration(milliseconds: _isPressed ? 80 : 150),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 52),
            width: double.infinity,
            decoration: decoration,
            alignment: Alignment.center,
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(onPrimary),
                    ),
                  )
                : Text(
                    widget.label,
                    style: AppTextStyles.title.copyWith(
                      color: onPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
