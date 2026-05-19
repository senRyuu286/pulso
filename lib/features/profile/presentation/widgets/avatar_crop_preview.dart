import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AvatarCropPreview extends StatefulWidget {
  const AvatarCropPreview({
    super.key,
    required this.imageBytes,
    required this.onConfirm,
    required this.onCancel,
  });

  final Uint8List imageBytes;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  State<AvatarCropPreview> createState() => _AvatarCropPreviewState();
}

class _AvatarCropPreviewState extends State<AvatarCropPreview> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceD : AppColors.surfaceL;
    final shadowLight = isDark ? AppColors.shadowLightD : AppColors.shadowLightL;
    final shadowDark = isDark ? AppColors.shadowDarkD : AppColors.shadowDarkL;
    final dividerColor = isDark ? AppColors.dividerD : AppColors.dividerL;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowLight,
            blurRadius: 18,
            offset: const Offset(-6, -6),
          ),
          BoxShadow(
            color: shadowDark,
            blurRadius: 18,
            offset: const Offset(6, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Preview Avatar',
            style: AppTextStyles.title.copyWith(
              color: isDark ? AppColors.textPrimaryD : AppColors.textPrimaryL,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: shadowLight,
                  blurRadius: 14,
                  offset: const Offset(-6, -6),
                ),
                BoxShadow(
                  color: shadowDark,
                  blurRadius: 14,
                  offset: const Offset(6, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.memory(
                widget.imageBytes,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your avatar will appear',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: shadowLight,
                          blurRadius: 14,
                          offset: const Offset(-6, -6),
                        ),
                        BoxShadow(
                          color: shadowDark,
                          blurRadius: 14,
                          offset: const Offset(6, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      'Retake',
                      style: AppTextStyles.label.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryD
                            : AppColors.textSecondaryL,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onConfirm,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primaryD : AppColors.primaryL,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: shadowLight,
                          blurRadius: 14,
                          offset: const Offset(-6, -6),
                        ),
                        BoxShadow(
                          color: shadowDark,
                          blurRadius: 14,
                          offset: const Offset(6, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      'Use Photo',
                      style: AppTextStyles.label.copyWith(
                        color: isDark
                            ? AppColors.onSecondaryD
                            : AppColors.onSecondaryL,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
