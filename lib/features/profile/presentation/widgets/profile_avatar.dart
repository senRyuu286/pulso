import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.size,
    this.showEditButton = false,
    this.onEditTap,
  });

  final String? avatarUrl;
  final double size;
  final bool showEditButton;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: avatarUrl ?? '',
            imageBuilder: (context, imageProvider) {
              return ClipOval(
                child: Image(
                  image: imageProvider,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              );
            },
            placeholder: (context, url) => _GradientPlaceholder(size: size),
            errorWidget: (context, url, error) =>
                _GradientPlaceholder(size: size),
          ),
        ),
        if (showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primaryD : AppColors.primaryL,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color:
                      isDark ? AppColors.onSecondaryD : AppColors.onSecondaryL,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            isDark ? AppColors.primaryMutedD : AppColors.primaryMutedL,
            isDark ? AppColors.amberD : AppColors.amberL,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.45,
          color: isDark ? AppColors.textPrimaryD : AppColors.textPrimaryL,
        ),
      ),
    );
  }
}
