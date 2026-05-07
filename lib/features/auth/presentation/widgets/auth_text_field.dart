import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.errorText,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? errorText;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceInsetD : AppColors.surfaceInsetL;
    final textPlaceholder =
        isDark ? AppColors.textPlaceholderD : AppColors.textPlaceholderL;
    final shadowLight = isDark ? AppColors.shadowLightD : AppColors.shadowLightL;
    final shadowDark = isDark ? AppColors.shadowDarkD : AppColors.shadowDarkL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: shadowLight.withValues(alpha: 0.9),
                  offset: const Offset(-4, -4),
                  blurRadius: 8,
                  blurStyle: BlurStyle.inner,
                ),
                BoxShadow(
                  color: shadowDark.withValues(alpha: 0.9),
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  style: AppTextStyles.body,
                  decoration: InputDecoration.collapsed(
                    hintText: hintText,
                    hintStyle: AppTextStyles.body.copyWith(
                      color: textPlaceholder,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.primaryD : AppColors.primaryL,
            ),
          ),
        ],
      ],
    );
  }
}
